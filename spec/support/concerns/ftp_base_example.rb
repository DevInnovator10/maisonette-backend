# frozen_string_literal: true

RSpec.shared_examples 'a Base FTP client' do
  let(:net_ftp) { instance_double(Net::FTP).as_null_object }
  let(:ftp_client) { nil }
  let(:some_files) { %w[file1 file2 file3] }

  before do
    allow(Net::FTP).to receive(:new).and_return(net_ftp)
    allow(net_ftp).to receive(:nlst).and_return(some_files)
    allow(FileUtils).to receive(:mkdir)
  end

  it 'calls the callback per each file' do
    expect(ftp_fetch).to eq some_files
  end

  describe '#open_connection' do
    before { ftp_fetch }

    it { expect(net_ftp).to have_received(:connect).with(hostname, port) }
    it { expect(net_ftp).to have_received(:login).with(username, password) }
  end

  describe '#close_connection' do
    before { ftp_fetch }

    it { expect(net_ftp).to have_received(:close) }
  end

  describe '#download_files' do
    it { expect(ftp_fetch).to eq some_files }

    context 'when the remote backup destination folder (if specified) doesn\'t exist' do
      it 'creates the remote folder' do
        allow(net_ftp).to receive(:size).and_raise(Net::FTPError.new('Path not found'))
        expect(ftp_fetch).to eq some_files
        expect(net_ftp).to have_received(:mkdir)
      end
    end
  end

  context 'when no files are found' do
    before do
      allow(net_ftp).to receive(:nlst).and_raise(Net::FTPTempError.new('No files found'))
    end

    it 'returns an empty array' do
      expect(ftp_fetch).to eq []
    end
  end
end
